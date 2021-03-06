#' @rdname subnets
#' @title Subnets
#' @description Get, create, and delete subnets
#' @details Use [create_netacl()] and [associate_netacl()] to specify a non-default Access Control List (ACL) for the subnet
#' @template subnet
#' @template filter
#' @template vpc
#' @template cidr
#' @param zone Optionally, a character string specifying an availability zone (see [describe_zones()]) or an object of class \dQuote{ec2_zone}. If omitted, a zone is selected automatically.
#' @template dots
#' @return A list of objects of class \dQuote{ec2_subnet}.
#' @references
#' <http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeSubnets.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateSubnet.html>
#' <http://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DeleteSubnet.html>
#' @examples
#' \dontrun{
#' # describe existing subnets
#' (d <- describe_subnets())
#' describe_subnets(d[[1]])
#' 
#' # create a subnet
#' ## setup new VPC IP address
#' new_ip <- allocate_ip("vpc")
#' aid <- describe_ips(new_ip$publicIp)[[1]]$allocationId
#' s <- create_subnet(aid, cidr = "10.0.1.0/24")
#' 
#' # delete a subnet
#' 
#' }
#' @seealso [create_vpc()], [create_netacl()], [associate_netacl()]
#' @keywords security
#' @export
describe_subnets <- function(subnet, filter, ...) {
    query <- list(Action = "DescribeSubnets")
    if (!missing(subnet)) {
        if (inherits(subnet, "ec2_subnet")) {
            subnet <- list(get_subnetid(subnet))
        } else if (is.character(subnet)) {
            subnet <- as.list(get_subnetid(subnet))
        } else {
            subnet <- lapply(subnet, get_subnetid)
        }
        names(subnet) <- paste0("SubnetId.", seq_along(subnet))
        query <- c(query, subnet)
    }
    if (!missing(filter)) {
        query <- c(query, .makelist(filter, type = "Filter"))
    }
    r <- ec2HTTP(query = query, ...)
    return(unname(lapply(r$subnetSet, function(z) {
        structure(flatten_list(z), class = "ec2_subnet")
    })))
}

#' @rdname subnets
#' @export
create_subnet <- function(vpc, cidr, zone, ...) {
    query <- list(Action = "CreateSubnet", CidrBlock = cidr)
    query$VpcId <- get_vpcid(vpc)
    if (!missing(zone)) {
        if (inherits(zone, "ec2_zone")) {
            zone <- zone$zoneName
        }
        query$AvailabilityZone <- zone
    }
    r <- ec2HTTP(query = query, ...)
    return(structure(r, class = "ec2_subnet"))
}

#' @rdname subnets
#' @export
delete_subnet <- function(subnet, ...) {
    query <- list(Action = "DeleteSubnet")
    query$SubnetId <- get_subnetid(subnet)
    r <- ec2HTTP(query = query, ...)
    if (r$return[[1]] == "true") {
        return(TRUE)
    } else { 
        return(FALSE)
    }
}

print.ec2_subnet <- function(x, ...) {
    cat("subnetId:            ", x$subnetId, "\n")
    cat("state:               ", x$state, "\n")
    cat("vpcId:               ", x$vpcId, "\n")
    cat("cidrBlock:           ", x$cidrBlock, "\n")
    cat("availableIp's:       ", x$availableIpAddressCount, "\n")
    cat("availabilityZone:    ", x$availabilityZone, "\n")
    cat("defaultForAz:        ", x$defaultForAz, "\n")
    cat("mapPublicIpOnLaunch: ", x$mapPublicIpOnLaunch, "\n")
    invisible(x)
}
